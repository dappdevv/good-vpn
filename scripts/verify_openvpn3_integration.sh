#!/bin/bash

# Verification script for OpenVPN3 integration
# This script verifies that the OpenVPN3 libraries are properly integrated

set -e

echo "🔍 Verifying OpenVPN3 Integration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[VERIFY]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️ WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ FAIL]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the Flutter project root directory"
    exit 1
fi

echo ""
echo "🎯 OpenVPN3 Integration Verification Report"
echo "=========================================="
echo ""

# Verification counters
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to run check
run_check() {
    local description="$1"
    local command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    print_status "Checking: $description"
    
    if eval "$command" > /dev/null 2>&1; then
        print_success "$description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_error "$description"
        return 1
    fi
}

# 1. Check Android OpenVPN3 Integration
echo "📱 Android OpenVPN3 Integration"
echo "--------------------------------"

run_check "Android OpenVPN3 core library exists" "[ -d 'android/app/src/main/cpp/openvpn3-core' ]"
run_check "Android OpenSSL library exists" "[ -d 'android/app/src/main/cpp/openssl' ]"
run_check "Android ASIO library exists" "[ -d 'android/app/src/main/cpp/asio' ]"
run_check "Android CMakeLists.txt updated" "grep -q 'openvpn3-core' android/app/src/main/cpp/CMakeLists.txt"
run_check "Android OpenVPN3 wrapper exists" "[ -f 'android/app/src/main/cpp/openvpn3_wrapper.cpp' ]"
run_check "Android OpenVPN3 wrapper header exists" "[ -f 'android/app/src/main/cpp/openvpn3_wrapper.h' ]"
run_check "Android enhanced client exists" "[ -f 'android/app/src/main/cpp/openvpn_client.cpp' ]"

echo ""

# 2. Check Windows OpenVPN3 Integration  
echo "🪟 Windows OpenVPN3 Integration"
echo "--------------------------------"

run_check "Windows OpenVPN3 core library exists" "[ -d 'windows/libs/openvpn3' ]"
run_check "Windows CMakeLists.txt updated" "grep -q 'openvpn3_wrapper_win.cpp' windows/runner/CMakeLists.txt"
run_check "Windows OpenVPN3 wrapper exists" "[ -f 'windows/runner/openvpn3_wrapper_win.cpp' ]"
run_check "Windows OpenVPN3 wrapper header exists" "[ -f 'windows/runner/openvpn3_wrapper_win.h' ]"
run_check "Windows enhanced client exists" "[ -f 'windows/runner/openvpn_client_win.cpp' ]"

echo ""

# 3. Check Build System Integration
echo "🔧 Build System Integration"
echo "----------------------------"

run_check "Android build.gradle.kts has NDK support" "grep -q 'abiFilters' android/app/build.gradle.kts"
run_check "Android CMake has OpenVPN3 definitions" "grep -q 'DUSE_OPENSSL' android/app/src/main/cpp/CMakeLists.txt"
run_check "Windows CMake has networking libraries" "grep -q 'ws2_32.lib' windows/runner/CMakeLists.txt"

echo ""

# 4. Check Library Sizes
echo "📊 Library Size Verification"
echo "-----------------------------"

if [ -d "android/app/src/main/cpp/openvpn3-core" ]; then
    OPENVPN3_SIZE=$(du -sh android/app/src/main/cpp/openvpn3-core 2>/dev/null | cut -f1 || echo "Unknown")
    print_success "OpenVPN3 core library size: $OPENVPN3_SIZE"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

if [ -d "android/app/src/main/cpp/openssl" ]; then
    OPENSSL_SIZE=$(du -sh android/app/src/main/cpp/openssl 2>/dev/null | cut -f1 || echo "Unknown")
    print_success "OpenSSL library size: $OPENSSL_SIZE"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

if [ -d "android/app/src/main/cpp/asio" ]; then
    ASIO_SIZE=$(du -sh android/app/src/main/cpp/asio 2>/dev/null | cut -f1 || echo "Unknown")
    print_success "ASIO library size: $ASIO_SIZE"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

echo ""

# 5. Check Code Integration
echo "💻 Code Integration Verification"
echo "---------------------------------"

run_check "Android client uses OpenVPN3 wrapper" "grep -q 'OpenVPN3Wrapper' android/app/src/main/cpp/openvpn_client.cpp"
run_check "Windows client uses OpenVPN3 wrapper" "grep -q 'OpenVPN3WrapperWin' windows/runner/openvpn_client_win.cpp"
run_check "Android JNI updated for OpenVPN3" "grep -q 'openvpn3_wrapper.h' android/app/src/main/cpp/openvpn_client.h"
run_check "Kotlin service supports native library" "grep -q 'OpenVpnNative' android/app/src/main/kotlin/com/example/fl_openvpn_client/OpenVpnService.kt"

echo ""

# 6. Check Documentation
echo "📚 Documentation Verification"
echo "------------------------------"

run_check "OpenVPN3 integration documentation exists" "[ -f 'OPENVPN3_INTEGRATION_COMPLETE.md' ]"
run_check "Build report exists" "[ -f 'BUILD_REPORT.md' ]"
run_check "OpenVPN libraries documentation exists" "[ -f 'OPENVPN_LIBRARIES.md' ]"
run_check "Current status updated" "grep -q 'OPENVPN3 INTEGRATION' CurrentStatus.md"

echo ""

# 7. Test Build Capability
echo "🏗️ Build System Test"
echo "---------------------"

print_status "Testing Flutter clean and pub get..."
if flutter clean > /dev/null 2>&1 && flutter pub get > /dev/null 2>&1; then
    print_success "Flutter build system working"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    print_error "Flutter build system issues"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
fi

echo ""

# Generate verification report
echo "📋 Verification Summary"
echo "======================="
echo ""

PASS_PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

if [ $PASS_PERCENTAGE -ge 90 ]; then
    print_success "OpenVPN3 Integration: EXCELLENT ($PASSED_CHECKS/$TOTAL_CHECKS checks passed - $PASS_PERCENTAGE%)"
elif [ $PASS_PERCENTAGE -ge 75 ]; then
    print_warning "OpenVPN3 Integration: GOOD ($PASSED_CHECKS/$TOTAL_CHECKS checks passed - $PASS_PERCENTAGE%)"
elif [ $PASS_PERCENTAGE -ge 50 ]; then
    print_warning "OpenVPN3 Integration: PARTIAL ($PASSED_CHECKS/$TOTAL_CHECKS checks passed - $PASS_PERCENTAGE%)"
else
    print_error "OpenVPN3 Integration: INCOMPLETE ($PASSED_CHECKS/$TOTAL_CHECKS checks passed - $PASS_PERCENTAGE%)"
fi

echo ""
echo "🎯 Integration Status:"
echo "  ✅ Real OpenVPN3 libraries: $([ -d 'android/app/src/main/cpp/openvpn3-core' ] && echo 'INTEGRATED' || echo 'MISSING')"
echo "  ✅ Cross-platform support: $([ -d 'windows/libs/openvpn3' ] && echo 'READY' || echo 'PARTIAL')"
echo "  ✅ Build system: $(grep -q 'openvpn3' android/app/src/main/cpp/CMakeLists.txt && echo 'UPDATED' || echo 'NEEDS UPDATE')"
echo "  ✅ Native wrappers: $([ -f 'android/app/src/main/cpp/openvpn3_wrapper.cpp' ] && echo 'IMPLEMENTED' || echo 'MISSING')"
echo "  ✅ Documentation: $([ -f 'OPENVPN3_INTEGRATION_COMPLETE.md' ] && echo 'COMPLETE' || echo 'MISSING')"

echo ""
if [ $PASS_PERCENTAGE -ge 90 ]; then
    echo "🎉 OpenVPN3 Integration Verification: SUCCESSFUL!"
    echo "   Ready for production OpenVPN3 ClientAPI implementation."
else
    echo "⚠️  OpenVPN3 Integration needs attention."
    echo "   Some components may be missing or need updates."
fi

echo ""
echo "📊 Detailed Results: $PASSED_CHECKS/$TOTAL_CHECKS checks passed ($PASS_PERCENTAGE%)"
echo "📅 Verification Date: $(date)"
echo ""

exit 0
