#pragma once

// Minimal ASIO headers for compilation
// In production, use actual ASIO library

#include <system_error>
#include <functional>

namespace asio {
    class io_context {
    public:
        void run() {}
        void stop() {}
    };
    
    template<typename Protocol>
    class basic_socket {
    public:
        void close() {}
    };
    
    namespace ip {
        class tcp {
        public:
            using socket = basic_socket<tcp>;
        };
        
        class udp {
        public:
            using socket = basic_socket<udp>;
        };
    }
}
