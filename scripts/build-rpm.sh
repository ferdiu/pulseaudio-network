#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PACKAGE_TYPE="${1:-both}"  # server, client, or both

# Clean and create build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"/{server,client}

echo "Building PulseAudio Network packages..."

build_server_rpm() {
    echo "Building server RPM..."

    # Create source structure
    mkdir -p "${BUILD_DIR}/server/rpmbuild"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    mkdir -p "${BUILD_DIR}/server/pulseaudio-network-server-1.0.0"/{src,systemd,firewalld,config}

    # Copy files
    cp "${SCRIPT_DIR}/src/pulseaudio-network-server" "${BUILD_DIR}/server/pulseaudio-network-server-1.0.0/src/"
    cp "${SCRIPT_DIR}/systemd/pulseaudio-network-server.service" "${BUILD_DIR}/server/pulseaudio-network-server-1.0.0/systemd/"
    cp "${SCRIPT_DIR}/firewalld/pulseaudio-network.xml" "${BUILD_DIR}/server/pulseaudio-network-server-1.0.0/firewalld/"
    cp "${SCRIPT_DIR}/config/server.json" "${BUILD_DIR}/server/pulseaudio-network-server-1.0.0/config/"
    cp "${SCRIPT_DIR}/README.md" "${BUILD_DIR}/server/pulseaudio-network-server-1.0.0/"
    cp "${SCRIPT_DIR}/LICENSE" "${BUILD_DIR}/server/pulseaudio-network-server-1.0.0/"

    # Create tarball
    cd "${BUILD_DIR}/server"
    tar czf "rpmbuild/SOURCES/pulseaudio-network-server-1.0.0.tar.gz" pulseaudio-network-server-1.0.0/

    # Copy spec file
    cp "${SCRIPT_DIR}/rpm/pulseaudio-network-server.spec" "rpmbuild/SPECS/"

    # Build RPM
    rpmbuild --define "_topdir $(pwd)/rpmbuild" -ba "rpmbuild/SPECS/pulseaudio-network-server.spec"

    echo "Server RPM built: ${BUILD_DIR}/server/rpmbuild/RPMS/"
}

build_client_rpm() {
    echo "Building client RPM..."

    # Create source structure
    mkdir -p "${BUILD_DIR}/client/rpmbuild"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    mkdir -p "${BUILD_DIR}/client/pulseaudio-network-client-1.0.0"/{src,systemd,config}

    # Copy files
    cp "${SCRIPT_DIR}/src/pulseaudio-network-client" "${BUILD_DIR}/client/pulseaudio-network-client-1.0.0/src/"
    cp "${SCRIPT_DIR}/systemd/pulseaudio-network-client.service" "${BUILD_DIR}/client/pulseaudio-network-client-1.0.0/systemd/"
    cp "${SCRIPT_DIR}/config/client.json" "${BUILD_DIR}/client/pulseaudio-network-client-1.0.0/config/"
    cp "${SCRIPT_DIR}/README.md" "${BUILD_DIR}/client/pulseaudio-network-client-1.0.0/"
    cp "${SCRIPT_DIR}/LICENSE" "${BUILD_DIR}/client/pulseaudio-network-client-1.0.0/"

    # Create tarball
    cd "${BUILD_DIR}/client"
    tar czf "rpmbuild/SOURCES/pulseaudio-network-client-1.0.0.tar.gz" pulseaudio-network-client-1.0.0/

    # Copy spec file
    cp "${SCRIPT_DIR}/rpm/pulseaudio-network-client.spec" "rpmbuild/SPECS/"

    # Build RPM
    rpmbuild --define "_topdir $(pwd)/rpmbuild" -ba "rpmbuild/SPECS/pulseaudio-network-client.spec"

    echo "Client RPM built: ${BUILD_DIR}/client/rpmbuild/RPMS/"
}

case "${PACKAGE_TYPE}" in
    server)
        build_server_rpm
        ;;
    client)
        build_client_rpm
        ;;
    both|*)
        build_server_rpm
        build_client_rpm
        ;;
esac

echo "Build complete!"
