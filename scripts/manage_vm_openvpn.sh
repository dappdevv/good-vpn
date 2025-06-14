#!/bin/bash

# OpenVPN Server Management Script for Ubuntu VM (mpvm01)
# This script manages the OpenVPN server running on the multipass VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}[OPENVPN-VM]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️ WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

# VM configuration
VM_NAME="mpvm01"
VM_IP="172.16.109.4"
OPENVPN_PORT="1194"

# Function to check if VM is running
check_vm_status() {
    if ! multipass list | grep -q "$VM_NAME.*Running"; then
        print_error "VM $VM_NAME is not running"
        print_info "Start the VM with: multipass start $VM_NAME"
        exit 1
    fi
    print_success "VM $VM_NAME is running"
}

# Function to start OpenVPN server
start_server() {
    print_header "Starting OpenVPN Server on $VM_NAME"
    
    check_vm_status
    
    print_info "Starting OpenVPN service..."
    multipass exec $VM_NAME -- sudo systemctl start openvpn@server
    
    print_info "Enabling OpenVPN service for auto-start..."
    multipass exec $VM_NAME -- sudo systemctl enable openvpn@server
    
    sleep 2
    
    if multipass exec $VM_NAME -- sudo systemctl is-active openvpn@server >/dev/null 2>&1; then
        print_success "OpenVPN server started successfully"
        print_info "Server listening on $VM_IP:$OPENVPN_PORT (UDP)"
    else
        print_error "Failed to start OpenVPN server"
        print_info "Check logs with: $0 logs"
        exit 1
    fi
}

# Function to stop OpenVPN server
stop_server() {
    print_header "Stopping OpenVPN Server on $VM_NAME"
    
    check_vm_status
    
    print_info "Stopping OpenVPN service..."
    multipass exec $VM_NAME -- sudo systemctl stop openvpn@server
    
    print_success "OpenVPN server stopped"
}

# Function to restart OpenVPN server
restart_server() {
    print_header "Restarting OpenVPN Server on $VM_NAME"
    
    check_vm_status
    
    print_info "Restarting OpenVPN service..."
    multipass exec $VM_NAME -- sudo systemctl restart openvpn@server
    
    sleep 2
    
    if multipass exec $VM_NAME -- sudo systemctl is-active openvpn@server >/dev/null 2>&1; then
        print_success "OpenVPN server restarted successfully"
        print_info "Server listening on $VM_IP:$OPENVPN_PORT (UDP)"
    else
        print_error "Failed to restart OpenVPN server"
        print_info "Check logs with: $0 logs"
        exit 1
    fi
}

# Function to show server status
show_status() {
    print_header "OpenVPN Server Status on $VM_NAME"
    
    check_vm_status
    
    echo ""
    print_info "Service Status:"
    multipass exec $VM_NAME -- sudo systemctl status openvpn@server --no-pager
    
    echo ""
    print_info "Network Status:"
    if multipass exec $VM_NAME -- sudo netstat -ulnp | grep -q ":$OPENVPN_PORT"; then
        print_success "OpenVPN is listening on port $OPENVPN_PORT (UDP)"
    else
        print_error "OpenVPN is not listening on port $OPENVPN_PORT"
    fi
    
    echo ""
    print_info "TUN Interface:"
    multipass exec $VM_NAME -- ip addr show tun0 2>/dev/null || print_warning "TUN interface not found"
    
    echo ""
    print_info "Connected Clients:"
    if multipass exec $VM_NAME -- test -f /var/log/openvpn/openvpn-status.log; then
        multipass exec $VM_NAME -- sudo cat /var/log/openvpn/openvpn-status.log | grep -A 10 "CLIENT_LIST" || print_info "No clients connected"
    else
        print_warning "Status log not found"
    fi
}

# Function to show server logs
show_logs() {
    print_header "OpenVPN Server Logs on $VM_NAME"
    
    check_vm_status
    
    print_info "Recent OpenVPN logs (last 20 lines):"
    multipass exec $VM_NAME -- sudo journalctl -u openvpn@server --no-pager -n 20
    
    echo ""
    print_info "To follow logs in real-time, run:"
    print_info "multipass exec $VM_NAME -- sudo journalctl -u openvpn@server -f"
}

# Function to fix network configuration
fix_network() {
    print_header "Fixing Network Configuration on $VM_NAME"
    
    check_vm_status
    
    print_info "Enabling IP forwarding..."
    multipass exec $VM_NAME -- sudo sysctl -w net.ipv4.ip_forward=1
    
    print_info "Configuring iptables rules..."
    
    # Remove old rules with wrong interface name
    multipass exec $VM_NAME -- sudo iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o enp0s2 -j MASQUERADE 2>/dev/null || true
    multipass exec $VM_NAME -- sudo iptables -D FORWARD -i tun+ -o enp0s2 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    multipass exec $VM_NAME -- sudo iptables -D FORWARD -i enp0s2 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    
    # Add correct rules with ens3 interface
    multipass exec $VM_NAME -- sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ens3 -j MASQUERADE
    multipass exec $VM_NAME -- sudo iptables -A INPUT -i tun+ -j ACCEPT
    multipass exec $VM_NAME -- sudo iptables -A FORWARD -i tun+ -j ACCEPT
    multipass exec $VM_NAME -- sudo iptables -A FORWARD -i tun+ -o ens3 -m state --state RELATED,ESTABLISHED -j ACCEPT
    multipass exec $VM_NAME -- sudo iptables -A FORWARD -i ens3 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    print_info "Saving iptables rules..."
    multipass exec $VM_NAME -- sudo netfilter-persistent save
    
    print_success "Network configuration fixed"
}

# Function to test connectivity
test_connectivity() {
    print_header "Testing OpenVPN Server Connectivity"
    
    check_vm_status
    
    print_info "Testing UDP connectivity to $VM_IP:$OPENVPN_PORT..."
    
    if command -v nc >/dev/null 2>&1; then
        if timeout 3 nc -u -v $VM_IP $OPENVPN_PORT < /dev/null 2>&1 | grep -q "succeeded\|Connected"; then
            print_success "UDP connectivity test passed"
        else
            print_error "UDP connectivity test failed"
            print_info "Check firewall and network configuration"
        fi
    else
        print_warning "netcat not available, skipping connectivity test"
    fi
    
    print_info "Testing with sample client config..."
    if [ -f "sample_configs/vm01.ovpn" ]; then
        print_success "Client configuration file exists: sample_configs/vm01.ovpn"
        print_info "You can now test with the Flutter OpenVPN client"
    else
        print_error "Client configuration file not found: sample_configs/vm01.ovpn"
        print_info "Run the setup script to create the client configuration"
    fi
}

# Function to show help
show_help() {
    echo "OpenVPN Server Management Script for Ubuntu VM"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start the OpenVPN server"
    echo "  stop        Stop the OpenVPN server"
    echo "  restart     Restart the OpenVPN server"
    echo "  status      Show server status and connected clients"
    echo "  logs        Show recent server logs"
    echo "  fix-network Fix network configuration (iptables, IP forwarding)"
    echo "  test        Test server connectivity"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start the OpenVPN server"
    echo "  $0 status                   # Check server status"
    echo "  $0 logs                     # View recent logs"
    echo "  $0 fix-network              # Fix network configuration"
    echo ""
    echo "VM Information:"
    echo "  VM Name: $VM_NAME"
    echo "  VM IP: $VM_IP"
    echo "  OpenVPN Port: $OPENVPN_PORT (UDP)"
    echo "  Client Config: sample_configs/vm01.ovpn"
}

# Main script logic
case "${1:-help}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    fix-network)
        fix_network
        ;;
    test)
        test_connectivity
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
