#!/usr/bin/env python3
import socket
import threading

def udp_forwarder(local_port, remote_host, remote_port):
    """Forward UDP packets from local_port to remote_host:remote_port"""

    # Create local UDP socket
    local_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    local_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    local_sock.bind(('0.0.0.0', local_port))
    print(f"UDP forwarder listening on 0.0.0.0:{local_port}")
    print(f"Forwarding to {remote_host}:{remote_port}")

    # Dictionary to track client connections
    clients = {}

    def forward_to_remote(data, client_addr):
        """Forward data from client to remote server"""
        try:
            # Create or reuse socket for this client
            if client_addr not in clients:
                remote_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                remote_sock.settimeout(30)  # 30 second timeout
                clients[client_addr] = remote_sock
                print(f"Created new remote socket for client {client_addr}")

                # Start thread to listen for responses from remote server
                def listen_for_response():
                    try:
                        while True:
                            response, server_addr = remote_sock.recvfrom(4096)
                            local_sock.sendto(response, client_addr)
                            print(f"Forwarded {len(response)} bytes from {server_addr} back to {client_addr}")
                    except socket.timeout:
                        print(f"Timeout waiting for response for client {client_addr}")
                    except Exception as e:
                        print(f"Error in response listener for {client_addr}: {e}")
                    finally:
                        if client_addr in clients:
                            del clients[client_addr]

                threading.Thread(target=listen_for_response, daemon=True).start()

            # Forward to remote server
            clients[client_addr].sendto(data, (remote_host, remote_port))
            print(f"Forwarded {len(data)} bytes from {client_addr} to {remote_host}:{remote_port}")

        except Exception as e:
            print(f"Error forwarding data: {e}")

    # Main loop
    try:
        while True:
            data, client_addr = local_sock.recvfrom(4096)
            print(f"Received {len(data)} bytes from {client_addr}")
            threading.Thread(target=forward_to_remote, args=(data, client_addr), daemon=True).start()
    except KeyboardInterrupt:
        print("Shutting down UDP forwarder...")
    finally:
        local_sock.close()
        for sock in clients.values():
            sock.close()

if __name__ == "__main__":
    # Forward local port 1194 to OpenVPN server
    udp_forwarder(1194, "172.16.109.4", 1194)
