#ifndef OPENVPN3_COMPAT_H
#define OPENVPN3_COMPAT_H

// OpenVPN3 Core compatibility header for Android NDK
// This ensures all necessary system headers are included before OpenVPN3 Core headers

// Standard C++ headers
#include <cstdint>
#include <cstring>
#include <string>
#include <memory>
#include <functional>
#include <system_error>

// Android NDK system headers
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

// Ensure ASIO compatibility
#ifndef ASIO_STANDALONE
#define ASIO_STANDALONE
#endif

#ifndef ASIO_HAS_STD_ADDRESSOF
#define ASIO_HAS_STD_ADDRESSOF 1
#endif

#ifndef ASIO_HAS_STD_ARRAY
#define ASIO_HAS_STD_ARRAY 1
#endif

#ifndef ASIO_HAS_CSTDINT
#define ASIO_HAS_CSTDINT 1
#endif

#ifndef ASIO_HAS_STD_SHARED_PTR
#define ASIO_HAS_STD_SHARED_PTR 1
#endif

#ifndef ASIO_HAS_STD_TYPE_TRAITS
#define ASIO_HAS_STD_TYPE_TRAITS 1
#endif

// Include ASIO headers before defining namespace alias
#include <asio.hpp>

// Define openvpn_io namespace alias for OpenVPN3 Core compatibility
// OpenVPN3 Core expects openvpn_io to be an alias for asio
namespace openvpn_io = asio;

// Ensure network byte order functions are available
#ifndef htonl
#include <endian.h>
#if __BYTE_ORDER == __LITTLE_ENDIAN
#define htonl(x) __builtin_bswap32(x)
#define htons(x) __builtin_bswap16(x)
#define ntohl(x) __builtin_bswap32(x)
#define ntohs(x) __builtin_bswap16(x)
#else
#define htonl(x) (x)
#define htons(x) (x)
#define ntohl(x) (x)
#define ntohs(x) (x)
#endif
#endif

// Ensure error_code is available in asio namespace for OpenVPN3 Core
namespace asio {
    using error_code = std::error_code;
}

#endif // OPENVPN3_COMPAT_H
