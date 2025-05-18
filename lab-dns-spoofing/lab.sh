#!/bin/bash

# Install nss-tools

sudo yum install -y nss-tools

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
    sudo cp cert.crt /etc/pki/tls/certs/
    sudo update-ca-trust enable
    sudo update-ca-trust extract
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