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

    # Find Firefox profile directory
    FF_PROFILE_DIR=$(grep -E 'Path=.*default' ~/.mozilla/firefox/profiles.ini | cut -d'=' -f2)
    if [ -z "$FF_PROFILE_DIR" ]; then
        echo "Error: Could not find Firefox default profile"
        exit 1
    fi

    FF_PROFILE_PATH="$HOME/.mozilla/firefox/$FF_PROFILE_DIR"

    # Check if profile directory exists
    if [ ! -d "$FF_PROFILE_PATH" ]; then
        echo "Error: Firefox profile directory $FF_PROFILE_PATH does not exist"
        exit 1
    fi

    # Add certificate to Firefox's NSS database
    echo "Adding certificate to Firefox profile: $FF_PROFILE_PATH"
    certutil -A -n "Self-Signed-Cert" -t "C,," -i "cert.crt" -d "sql:$FF_PROFILE_PATH"

    if [ $? -eq 0 ]; then
        echo "Certificate successfully added to Firefox"
    else
        echo "Error: Failed to add certificate"
        exit 1
    fi

    if pgrep firefox > /dev/null; then
        echo "Restarting Firefox to apply changes..."
        pkill firefox
        firefox &> /dev/null &
    fi

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