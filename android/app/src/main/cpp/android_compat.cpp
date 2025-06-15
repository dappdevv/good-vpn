// Android compatibility layer for OpenVPN3 Core
// This file provides minimal Android-specific compatibility functions

#include <android/log.h>
#include <unistd.h>
#include <sys/types.h>

// Android logging wrapper
void android_log_print(int priority, const char* tag, const char* format, ...) {
    va_list args;
    va_start(args, format);
    __android_log_vprint(priority, tag, format, args);
    va_end(args);
}

// Stub implementations for missing functions that may be needed
extern "C" {
    // These are provided by the Android NDK, but we include stubs just in case
    int getpid() { return ::getpid(); }
    int getuid() { return ::getuid(); }
    int geteuid() { return ::geteuid(); }
}
