// Android compatibility layer for OpenVPN3 Core
// This file provides minimal Android-specific compatibility functions

#include <android/log.h>
#include <unistd.h>
#include <sys/types.h>
#include <cstdarg>
#include <cstdio>

// Android logging wrapper
void android_log_print(int priority, const char* tag, const char* format, ...) {
    va_list args;
    va_start(args, format);
    __android_log_vprint(priority, tag, format, args);
    va_end(args);
}

// Ensure stdio symbols are available for fmt library
// These should be provided by NDK, but we'll make sure they're linked
extern "C" {
    // Reference the NDK stdio symbols to ensure they're linked
    void ensure_stdio_symbols() {
        // This function ensures stderr and stdout are linked from NDK
        (void)stderr;
        (void)stdout;
    }
}
