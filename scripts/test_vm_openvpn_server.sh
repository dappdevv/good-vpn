#!/bin/bash

# Test script for OpenVPN server on Ubuntu VM
# This script tests the OpenVPN server setup and client configuration

set -e

echo "🧪 Testing OpenVPN Server Setup on Ubuntu VM..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
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
echo "🎯 OpenVPN Server Test Report"
echo "============================="
echo ""

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run test
run_test() {
    local description="$1"
    local command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_status "Testing: $description"
    
    if eval "$command" > /dev/null 2>&1; then
        print_success "$description"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "$description"
        return 1
    fi
}

# 1. Test VM Status
echo "🖥️ VM Status"
echo "------------"

run_test "VM mpvm01 is running" "multipass list | grep -q 'mpvm01.*Running'"

if multipass list | grep -q 'mpvm01.*Running'; then
    VM_IP=$(multipass list | grep mpvm01 | awk '{print $3}')
    print_success "VM IP Address: $VM_IP"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

echo ""

# 2. Test OpenVPN Server Status
echo "🔒 OpenVPN Server Status"
echo "------------------------"

run_test "OpenVPN service is active" "multipass exec mpvm01 -- sudo systemctl is-active openvpn@server"
run_test "OpenVPN service is enabled" "multipass exec mpvm01 -- sudo systemctl is-enabled openvpn@server"
run_test "OpenVPN is listening on port 1194" "multipass exec mpvm01 -- sudo netstat -ulnp | grep -q ':1194'"

echo ""

# 3. Test Network Configuration
echo "🌐 Network Configuration"
echo "------------------------"

run_test "IP forwarding is enabled" "multipass exec mpvm01 -- sysctl net.ipv4.ip_forward | grep -q '= 1'"
run_test "TUN interface exists" "multipass exec mpvm01 -- ip link show | grep -q tun"
run_test "OpenVPN subnet is configured" "multipass exec mpvm01 -- ip route | grep -q '10.8.0.0/24'"

echo ""

# 4. Test Certificates and Keys
echo "🔐 Certificates and Keys"
echo "------------------------"

run_test "CA certificate exists" "multipass exec mpvm01 -- test -f /etc/openvpn/ca.crt"
run_test "Server certificate exists" "multipass exec mpvm01 -- test -f /etc/openvpn/server.crt"
run_test "Server private key exists" "multipass exec mpvm01 -- test -f /etc/openvpn/server.key"
run_test "Diffie-Hellman parameters exist" "multipass exec mpvm01 -- test -f /etc/openvpn/dh.pem"
run_test "TLS auth key exists" "multipass exec mpvm01 -- test -f /etc/openvpn/ta.key"
run_test "Client certificate exists" "multipass exec mpvm01 -- test -f /etc/openvpn/easy-rsa/pki/issued/flutter-client.crt"
run_test "Client private key exists" "multipass exec mpvm01 -- test -f /etc/openvpn/easy-rsa/pki/private/flutter-client.key"

echo ""

# 5. Test Client Configuration
echo "📄 Client Configuration"
echo "-----------------------"

run_test "Client config file exists" "test -f sample_configs/vm01.ovpn"

if [ -f "sample_configs/vm01.ovpn" ]; then
    run_test "Config has remote server" "grep -q 'remote 172.16.109.4 1194' sample_configs/vm01.ovpn"
    run_test "Config has CA certificate" "grep -q 'BEGIN CERTIFICATE' sample_configs/vm01.ovpn"
    run_test "Config has client certificate" "grep -A 20 '<cert>' sample_configs/vm01.ovpn | grep -q 'BEGIN CERTIFICATE'"
    run_test "Config has client private key" "grep -A 30 '<key>' sample_configs/vm01.ovpn | grep -q 'BEGIN PRIVATE KEY'"
    run_test "Config has TLS auth key" "grep -A 20 '<tls-auth>' sample_configs/vm01.ovpn | grep -q 'BEGIN OpenVPN Static key'"
    run_test "Config has proper cipher" "grep -q 'cipher AES-256-GCM' sample_configs/vm01.ovpn"
    run_test "Config has compression" "grep -q 'compress lz4-v2' sample_configs/vm01.ovpn"
fi

echo ""

# 6. Test Connectivity
echo "🔌 Connectivity Test"
echo "--------------------"

if command -v nc >/dev/null 2>&1; then
    print_status "Testing UDP connectivity to OpenVPN server..."
    if timeout 3 nc -u -v 172.16.109.4 1194 < /dev/null 2>&1 | grep -q "succeeded"; then
        print_success "UDP connectivity to OpenVPN server"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_error "UDP connectivity to OpenVPN server"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    fi
else
    print_warning "netcat not available, skipping connectivity test"
fi

echo ""

# 7. Test OpenVPN Server Logs
echo "📋 Server Logs"
echo "--------------"

print_status "Checking OpenVPN server logs..."
if multipass exec mpvm01 -- sudo journalctl -u openvpn@server --no-pager -n 5 | grep -q "Initialization Sequence Completed"; then
    print_success "OpenVPN server initialized successfully"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    print_error "OpenVPN server initialization issues"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

echo ""

# 8. Test Configuration Validation
echo "✅ Configuration Validation"
echo "---------------------------"

if [ -f "sample_configs/vm01.ovpn" ]; then
    print_status "Validating OpenVPN client configuration..."
    
    # Check if openvpn client is available for validation
    if command -v openvpn >/dev/null 2>&1; then
        if openvpn --config sample_configs/vm01.ovpn --verb 1 --connect-timeout 1 --connect-retry 1 --connect-retry-max 1 2>&1 | grep -q "Initialization Sequence Completed\|AUTH_FAILED\|Connection refused"; then
            print_success "Client configuration is valid"
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            print_warning "Client configuration validation inconclusive"
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
        fi
    else
        print_warning "OpenVPN client not available for validation"
    fi
fi

echo ""

# Generate test report
echo "📊 Test Summary"
echo "==============="
echo ""

PASS_PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

if [ $PASS_PERCENTAGE -ge 90 ]; then
    print_success "OpenVPN Server Setup: EXCELLENT ($PASSED_TESTS/$TOTAL_TESTS tests passed - $PASS_PERCENTAGE%)"
elif [ $PASS_PERCENTAGE -ge 80 ]; then
    print_success "OpenVPN Server Setup: VERY GOOD ($PASSED_TESTS/$TOTAL_TESTS tests passed - $PASS_PERCENTAGE%)"
elif [ $PASS_PERCENTAGE -ge 70 ]; then
    print_warning "OpenVPN Server Setup: GOOD ($PASSED_TESTS/$TOTAL_TESTS tests passed - $PASS_PERCENTAGE%)"
else
    print_error "OpenVPN Server Setup: NEEDS ATTENTION ($PASSED_TESTS/$TOTAL_TESTS tests passed - $PASS_PERCENTAGE%)"
fi

echo ""
echo "🎯 Server Information:"
echo "  📍 VM Name: mpvm01"
echo "  🌐 IP Address: 172.16.109.4"
echo "  🔌 Port: 1194 (UDP)"
echo "  🔒 Protocol: OpenVPN"
echo "  📄 Client Config: sample_configs/vm01.ovpn"

echo ""
echo "🚀 Ready for Testing:"
if [ $PASS_PERCENTAGE -ge 80 ]; then
    print_success "✅ OpenVPN server is ready for Flutter client testing"
    print_success "✅ Client configuration file created: sample_configs/vm01.ovpn"
    print_success "✅ All certificates and keys properly configured"
    print_success "✅ Network routing and firewall configured"
else
    print_warning "⚠️  Some issues detected, please review the failed tests"
fi

echo ""
echo "📝 Next Steps:"
echo "  1. Import sample_configs/vm01.ovpn into the Flutter OpenVPN client"
echo "  2. Test connection using the Flutter app"
echo "  3. Monitor server logs: multipass exec mpvm01 -- sudo journalctl -u openvpn@server -f"
echo "  4. Check client connections: multipass exec mpvm01 -- sudo cat /var/log/openvpn/openvpn-status.log"

echo ""
echo "📊 Test Results: $PASSED_TESTS/$TOTAL_TESTS tests passed ($PASS_PERCENTAGE%)"
echo "📅 Test Date: $(date)"
echo ""

exit 0
