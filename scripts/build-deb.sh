#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build-deb"
DIST_DIR="${SCRIPT_DIR}/dist"
PACKAGE_TYPE="${1:-both}"  # server, client, or both
VERSION="1.0.0"

# Clean and create build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"/{server,client}

echo "Building PulseAudio Network DEB packages..."

build_server_deb() {
    echo "Building server DEB..."

    # Create package structure
    cd "${BUILD_DIR}/server"
    mkdir -p pulseaudio-network-server-${VERSION}/{src,systemd,firewalld,config,debian}

    # Copy source files
    cp "${SCRIPT_DIR}/src/pulseaudio-network-server" pulseaudio-network-server-${VERSION}/src/
    cp "${SCRIPT_DIR}/systemd/pulseaudio-network-server.service" pulseaudio-network-server-${VERSION}/systemd/
    cp "${SCRIPT_DIR}/firewalld/pulseaudio-network.xml" pulseaudio-network-server-${VERSION}/firewalld/
    cp "${SCRIPT_DIR}/config/server.json" pulseaudio-network-server-${VERSION}/config/
    cp "${SCRIPT_DIR}/README.md" pulseaudio-network-server-${VERSION}/
    cp "${SCRIPT_DIR}/LICENSE" pulseaudio-network-server-${VERSION}/

    # Copy debian control files
    cp -r "${SCRIPT_DIR}/debian/server/"* pulseaudio-network-server-${VERSION}/debian/

    # Build package
    cd pulseaudio-network-server-${VERSION}
    dpkg-buildpackage -us -uc -b

    echo "Server DEB built: ${BUILD_DIR}/server/"

    # Copy debs to dist directory
    mkdir -p "${DIST_DIR}"
    cp "${BUILD_DIR}/server/"*.deb "${DIST_DIR}/"
}

build_client_deb() {
    echo "Building client DEB..."

    # Create package structure
    cd "${BUILD_DIR}/client"
    mkdir -p pulseaudio-network-client-${VERSION}/{src,systemd,config,debian}

    # Copy source files
    cp "${SCRIPT_DIR}/src/pulseaudio-network-client" pulseaudio-network-client-${VERSION}/src/
    cp "${SCRIPT_DIR}/src/pulseaudio-network-client-config" pulseaudio-network-client-${VERSION}/src/
    cp "${SCRIPT_DIR}/systemd/pulseaudio-network-client@.service" pulseaudio-network-client-${VERSION}/systemd/
    cp "${SCRIPT_DIR}/systemd/pulseaudio-network-client.service" pulseaudio-network-client-${VERSION}/systemd/
    cp "${SCRIPT_DIR}/config/client.json" pulseaudio-network-client-${VERSION}/config/
    cp "${SCRIPT_DIR}/README.md" pulseaudio-network-client-${VERSION}/
    cp "${SCRIPT_DIR}/LICENSE" pulseaudio-network-client-${VERSION}/

    # Copy debian control files
    cp -r "${SCRIPT_DIR}/debian/client/"* pulseaudio-network-client-${VERSION}/debian/

    # Build package
    cd pulseaudio-network-client-${VERSION}
    dpkg-buildpackage -us -uc -b

    echo "Client DEB built: ${BUILD_DIR}/client/"

    # Copy debs to dist directory
    mkdir -p "${DIST_DIR}"
    cp "${BUILD_DIR}/client/"*.deb "${DIST_DIR}/"
}

case "${PACKAGE_TYPE}" in
    server)
        build_server_deb
        ;;
    client)
        build_client_deb
        ;;
    both|*)
        build_server_deb
        build_client_deb
        ;;
esac

echo "Build complete!"
