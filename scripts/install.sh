#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_TYPE="${1:-both}"  # server, client, or both
PREFIX="${2:-/usr/local}"

echo "Installing PulseAudio Network from source..."

install_server() {
    echo "Installing server..."

    # Install binary
    sudo install -m 755 "${SCRIPT_DIR}/src/pulseaudio-network-server" "${PREFIX}/bin/"

    # Install systemd user service
    sudo install -D -m 644 "${SCRIPT_DIR}/systemd/pulseaudio-network-server.service" \
        "/usr/lib/systemd/user/pulseaudio-network-server.service"

    # Install firewalld service definition
    sudo install -D -m 644 "${SCRIPT_DIR}/firewalld/pulseaudio-network.xml" \
        "/usr/lib/firewalld/services/pulseaudio-network.xml"

    # Install default configuration
    sudo install -D -m 644 "${SCRIPT_DIR}/config/server.json" \
        "/etc/pulseaudio-network/server.json"

    echo "Server installed successfully!"
}

install_client() {
    echo "Installing client..."

    # Install binary
    sudo install -m 755 "${SCRIPT_DIR}/src/pulseaudio-network-client" "${PREFIX}/bin/"

    # Install systemd user service
    sudo install -D -m 644 "${SCRIPT_DIR}/systemd/pulseaudio-network-client.service" \
        "/usr/lib/systemd/user/pulseaudio-network-client.service"

    # Install default configuration
    sudo install -D -m 644 "${SCRIPT_DIR}/config/client.json" \
        "/etc/pulseaudio-network/client.json"

    echo "Client installed successfully!"
}

case "${PACKAGE_TYPE}" in
    server)
        install_server
        ;;
    client)
        install_client
        ;;
    both|*)
        install_server
        install_client
        ;;
esac

# Reload systemd and firewalld
sudo systemctl daemon-reload
if systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --reload
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Copy configuration to user directory:"
echo "   mkdir -p ~/.config/pulseaudio-network"
echo "   cp /etc/pulseaudio-network/*.json ~/.config/pulseaudio-network/"
echo ""
echo "2. Edit configuration files as needed"
echo ""
echo "3. Enable and start services:"
echo "   systemctl --user enable pulseaudio-network-server.service  # for server"
echo "   systemctl --user enable pulseaudio-network-client.service  # for client"
echo "   systemctl --user start pulseaudio-network-server.service   # for server"
echo "   systemctl --user start pulseaudio-network-client.service   # for client"
