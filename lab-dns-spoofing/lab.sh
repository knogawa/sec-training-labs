#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Install nss-tools
yum install -y nss-tools

# Variables for IP and hostname
IP="127.0.0.1"
HOSTNAME="www.smbc.co.jp"
HOSTS_FILE="/etc/hosts"
ENTRY="$IP $HOSTNAME"

# Check if entry already exists
if grep -q "$ENTRY" "$HOSTS_FILE"; then
    echo "Entry already exists in hosts file, proceeding with next instructions"
else
    # Add entry to hosts file
    echo "$ENTRY" >> "$HOSTS_FILE"
    if [ $? -eq 0 ]; then
        echo "Successfully added $ENTRY to $HOSTS_FILE"
    else
        echo "Failed to add entry to $HOSTS_FILE"
        exit 1
    fi
fi

# Check if index.html exists; generate only if missing
if [ ! -f index.html ]; then
    echo "Downloading index.html."
    wget https://raw.githubusercontent.com/knogawa/sec-training-labs/refs/heads/main/lab-dns-spoofing/index.html
else
    echo "Using existing index.html."
fi

# Check if certificates exist; generate only if missing
if [ ! -f cert.crt ] || [ ! -f key.pem ]; then
    echo "Generating SSL certificates..."
    openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.crt -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"
    cp cert.crt /etc/pki/tls/certs/
    update-ca-trust enable
    update-ca-trust extract
else
    echo "Using existing SSL certificates."
fi

# Run the Python HTTPS server with multi-line code
echo "Starting HTTPS server on https://localhost..."
python3 - << 'EOF'
import http.server
import ssl
import socketserver

# Configuration
PORT = 443
Handler = http.server.SimpleHTTPRequestHandler

# Create server
httpd = socketserver.TCPServer(('', PORT), Handler)

# Set up SSL context
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile='cert.crt', keyfile='key.pem')

# Wrap socket with SSL
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

# Start server
print(f"Serving HTTPS on https://localhost:{PORT}")
httpd.serve_forever()
EOF